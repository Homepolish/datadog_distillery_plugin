defmodule Mix.Releases.DatadogPlugin do
  @moduledoc """
  Allows processing of a Distillery release for use with Datadog agent.
  """
  use Mix.Releases.Plugin

  alias Mix.Releases.Release
  alias Mix.Releases.Utils
  alias Mix.Releases.Archiver.Archive

  @apt_path ".apt"
  @apt_tar "apt.tar.gz"

  @impl Mix.Releases.Plugin
  def before_assembly(release, _opts), do: release

  @impl Mix.Releases.Plugin
  def after_assembly(release, _opts), do: release

  @impl Mix.Releases.Plugin
  def before_package(release, _opts), do: release

  @impl Mix.Releases.Plugin
  def after_package(%Release{} = release, _opts) do
    info("Installing Datadog agent to release")
    debug("Updating archive..")
    initial_tar_path = Release.archive_path(release)

    # Rebuild tar with datadog included
    with {:ok, tmpdir} <- Utils.insecure_mkdir_temp(),
         {:ok, _} <- Archive.extract(initial_tar_path, tmpdir),
         :ok <- File.rm(initial_tar_path),
         {:ok, _} <- move_apt(tmpdir),
         archive = make_archive(release, tmpdir),
         {:ok, _archive_path} <- save_archive(release, archive),
         _ <- File.rm_rf(tmpdir) do
      nil
    end
  end

  ## PRIVATE FUNCTIONS

  defp move_apt(tmpdir) do
    target = Path.join(tmpdir, @apt_path)

    with {_, 0} <- System.cmd("tar", ["-czf", @apt_tar, @apt_path]),
         {:ok, _} <- Archive.extract(@apt_tar, tmpdir),
         :ok <- File.rm(@apt_tar) do
      {:ok, target}
    else
      {:error, reason} -> raise reason
      {_, code} when code != 0 -> raise "System cmd exited with non-zero status code"
    end
  end

  defp make_archive(%Release{profile: %{output_dir: output_dir}} = release, tmpdir) do
    name = "#{release.name}"

    Path.wildcard("#{tmpdir}/*", match_dot: true)
    |> Enum.reduce(Archive.new(name, output_dir), fn source, acc ->
      Archive.add(acc, source, Path.relative_to(source, tmpdir))
    end)
  end

  defp save_archive(
         %Release{version: version},
         %Archive{name: name, manifest: manifest, working_dir: output_dir}
       ) do
    debug("Saving archive..")
    target_dir = Path.join([output_dir, "releases", version])
    tarfile = Path.join([target_dir, name <> ".tar.gz"])

    with :ok <- :erl_tar.create(String.to_charlist(tarfile), to_erl_tar_manifest(manifest), [:compressed]) do
      debug("Archive saved!")
      {:ok, tarfile}
    end
  end

  defp to_erl_tar_manifest(manifest) when is_map(manifest) do
    Enum.reduce(manifest, [], fn {k, v}, acc -> [{String.to_charlist(k), String.to_charlist(v)} | acc] end)
  end
end

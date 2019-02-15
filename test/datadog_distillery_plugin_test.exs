defmodule Mix.Releases.DatadogPluginTest do
  use ExUnit.Case

  alias Mix.Releases.Release
  alias Mix.Releases.Utils

  setup do
    [rel: Release.new("foo", "0.0.0")]
  end

  test "before_assembly/2", %{rel: rel} do
    assert Mix.Releases.DatadogPlugin.before_assembly(rel, []) == rel
  end

  test "after_assembly/2", %{rel: rel} do
    assert Mix.Releases.DatadogPlugin.after_assembly(rel, []) == rel
  end

  test "before_package/2", %{rel: rel} do
    assert Mix.Releases.DatadogPlugin.before_package(rel, []) == rel
  end

  describe "after_package/2" do
    setup do
      name = :crypto.strong_rand_bytes(8) |> Base.url_encode64() |> binary_part(0, 8)
      rel = Release.new(name, "0.0.0")

      File.mkdir_p!(Release.version_path(rel))

      on_exit(fn ->
        File.rm_rf!(rel.profile.output_dir)
        File.rm_rf(Path.join([File.cwd!(), ".apt"]))
      end)

      [rel: rel]
    end

    test "missing archive returns error", %{rel: rel} do
      error = {:error, {:archiver, {:erl_tar, {String.to_charlist(Release.archive_path(rel)), :enoent}}}}
      assert error == Mix.Releases.DatadogPlugin.after_package(rel, [])
    end

    test "missing .apt folder returns error", %{rel: rel} do
      tarfile = Release.archive_path(rel)
      create_initial_tar(tarfile)

      assert_raise RuntimeError, "System cmd exited with non-zero status code", fn ->
        Mix.Releases.DatadogPlugin.after_package(rel, [])
      end
    end

    test "archives without error", %{rel: rel} do
      tarfile = Release.archive_path(rel)
      create_initial_tar(tarfile)
      create_apt_dir()

      assert is_nil(Mix.Releases.DatadogPlugin.after_package(rel, []))
    end
  end

  ## PRIVATE FUNCTIONS

  defp create_initial_tar(tarfile) do
    working_dir = Utils.insecure_mkdir_temp!()

    baz_path = Path.join([working_dir, "foo", "bar", "baz.txt"])

    File.mkdir_p!(Path.join([working_dir, "foo", "bar"]))
    File.write!(baz_path, "hello!\n")

    qux_path = Path.join([working_dir, "qux.txt"])
    File.write!(qux_path, "hello again!\n")

    manifest = %{"foo/bar/baz.txt" => baz_path, "qux.txt" => qux_path}

    :ok = :erl_tar.create(String.to_charlist(tarfile), to_erl_tar_manifest(manifest), [:compressed])
  end

  defp create_apt_dir() do
    File.mkdir_p!(Path.join([File.cwd!(), ".apt"]))
    File.write!(Path.join([File.cwd!(), ".apt", "foo.txt"]), "hello!\n")
  end

  defp to_erl_tar_manifest(manifest) when is_map(manifest) do
    Enum.reduce(manifest, [], fn {k, v}, acc -> [{String.to_charlist(k), String.to_charlist(v)} | acc] end)
  end
end

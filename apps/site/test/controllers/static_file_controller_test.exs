defmodule Site.StaticFileControllerTest do
  use Site.ConnCase

  describe "index/2" do
    test "forwards files from config:content:drupal:root" do
      bypass = Bypass.open
      set_drupal_root("http://localhost:#{bypass.port}")

      Bypass.expect bypass, fn conn ->
        assert "/path" == conn.request_path
        Plug.Conn.resp(conn, 200, "file from drupal")
      end

      conn = %{build_conn() | request_path: "/path"}
      response = Site.StaticFileController.index(conn, [])
      assert response.status == 200
      assert response.resp_body == "file from drupal"
    end
  end

  defp set_drupal_root(new_domain) do
    old_config = Application.get_env(:content, :drupal)
    new_config = case old_config do
      nil -> [root: new_domain]
      keywordlist -> Keyword.put(keywordlist, :root, new_domain)
    end
    Application.put_env(:content, :drupal, new_config)
    on_exit fn ->
      Application.put_env(:content, :drual, old_config)
    end
  end
end

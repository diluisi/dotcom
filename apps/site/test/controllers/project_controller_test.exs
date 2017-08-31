defmodule Site.ProjectControllerTest do
  use Site.ConnCase, async: true

  describe "index" do
    test "renders the list of projects", %{conn: conn} do
      conn = get conn, project_path(conn, :index)
      assert html_response(conn, 200) =~ "<h1>T-Projects</h1>"
    end
  end

  describe "show" do
    test "renders a project", %{conn: conn} do
      conn = get conn, project_path(conn, :show, "2679")
      assert html_response(conn, 200) =~ "<h1>Ruggles Station Platform Project</h1>"
    end
  end

  describe "update" do
    test "renders a project update", %{conn: conn} do
      conn = get conn, project_path(conn, :project_update, "2679", "123")
      assert html_response(conn, 200) =~ "<h1>Project Update</h1>"
    end
  end
end

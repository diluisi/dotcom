defmodule Site.ProjectController do
  use Site.Web, :controller

  def index(conn, _) do
    projects = Content.Repo.projects()
    featured_projects = Enum.filter(projects, & &1.featured)

    render(conn, "index.html", %{
      breadcrumbs: [Breadcrumb.build("T-Projects")],
      projects: projects,
      featured_projects: featured_projects,
    })
  end

  def show(conn, %{"id" => id}) do
    project = Content.Repo.project!(id)
    updates = Content.Repo.project_updates([project_id: id])
    meetings = Content.Repo.events([project_id: id])
    breadcrumbs = [
      Breadcrumb.build("T-Projects", project_path(conn, :index)),
      Breadcrumb.build(project.title)]
    render conn, "show.html", %{
      breadcrumbs: breadcrumbs,
      project: project,
      updates: updates,
      meetings: meetings
    }
  end

  def project_update(conn, %{"project_id" => project_id, "id" => id}) do
    project = Content.Repo.project!(project_id)
    update = Content.Repo.project_update!(id)
    render conn, "update.html", project: project, update: update
  end
end

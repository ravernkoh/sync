defmodule SyncWeb.DeckController do
  use SyncWeb, :controller
  alias Sync.Decks

  plug :scrub_params, "deck" when action in [:secure_show]

  def new(conn, _params) do
    decks = Decks.list_decks()
    changeset = Decks.change_deck()
    render conn, "new.html", changeset: changeset, decks: decks
  end

  def create(conn, %{"deck" => deck_params}) do
    if !deck_params["images"] do
      conn
      |> put_flash(:error, "You need to put some images in!")
      |> redirect(to: deck_path(conn, :new))
    else
      upload_image_and_create_deck(conn, deck_params)
    end
  end

  defp upload_image_and_create_deck(conn, deck_params) do
    case Decks.create_deck(deck_params) do
      {:ok, deck} ->
        redirect conn, to: deck_path(conn, :show, deck)
      {:error, :upload_error} ->
        conn
        |> put_flash(:error, "Error occured while uploading the images.")
        |> redirect(to: deck_path(conn, :new))
      {:error, changeset} ->
        render conn, "new.html", changeset: changeset
    end
  end

  def show(conn, %{"id" => id}) do
    deck = Decks.find_deck!(id)
    if deck.password do
      redirect conn, to: deck_path(conn, :verify, deck_id: id)
    else
      render conn, "show.html", deck: deck, title: deck.title
    end
  end

  def secure_show(conn, %{"id" => id, "deck" => %{"password" => password}}) do
    deck = Decks.find_deck!(id)
    if password == deck.password do
      render conn, "show.html", deck: deck, title: deck.title, password: password
    else
      conn
      |> put_flash(:error, "Wrong password!")
      |> render("verify.html", deck_id: deck.id)
    end
  end

  def verify(conn, %{"deck_id" => id}) do
    render conn, "verify.html", deck_id: id
  end
end

defmodule RemoveDups do
  @moduledoc """
  Documentation for RemoveDups.
  """
  def clean_phone(n) do
    String.replace(n, ~r/\(|\)|\-|\s/, "")
  end

  def add_line_or_not(last = %{lines: lines, phones: phones}, file) do
    case lines do
      [] -> nil
      _ ->
        phone = case g = get_phone(hd(lines)) do
          nil -> :error
          _ -> g
        end
        IO.inspect phone
        cond do
          !(Enum.member?(phones, phone)) ->
            new_phones = List.insert_at(phones, -1, get_phone(hd(lines)))
            {:ok, data} = hd(lines)
            IO.write(file, "#{Enum.join(data, ",")}\n")
            add_line_or_not(%{lines: tl(lines), phones: new_phones}, file)
          phone == :error ->
            {:ok, data} = hd(lines)
            IO.write(file, "#{Enum.join(data, ",")}\n")
            add_line_or_not(%{lines: tl(lines), phones: phones}, file)
          true ->
            add_line_or_not(%{lines: tl(lines), phones: phones}, file)
        end
    end
  end

  def get_csvs(filename) do
    {:ok, file} = File.open("naha_dedup_phone.csv", [:write, :append])
    lines = get_lines(filename)
    out = add_line_or_not(%{lines: lines, phones: []}, file)
          |> Enum.map(fn({:ok, line}) -> line end)
  end


  def get_phone(line) do
    case line do
      {:ok, list} ->
        Enum.map(list, fn(x) -> clean_phone(x) end)
        |> Enum.find(fn(x) -> Regex.match?(~r/\d{9}/, x) end)
      _ -> :error
    end
  end

  def get_lines(filename) do
    IO.puts "-> getting file: #{filename}"
    File.stream!(filename)
    |> CSV.decode
    |> Enum.to_list
    |> tl() # strip off the header
  end
end

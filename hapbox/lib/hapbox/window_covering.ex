defmodule HAPBox.WindowCovering do
  @moduledoc """
  Responsible for managing the state of a window covering
  """

  @behaviour HAP.ValueStore

  use GenServer

  require Logger

  # It takes 27s to fully close the blind
  @percent_per_second 100 / 27
  @closing 0
  @opening 1
  @stopped 2

  @i2c_bus "i2c-1"
  @i2c_device 0x27
  @no_buttons_pressed 0xFF
  @close_button_pressed 0xFD
  @open_button_pressed 0xFB
  @stop_button_pressed 0xFE

  def start_link(config) do
    GenServer.start_link(__MODULE__, config, name: __MODULE__)
  end

  @impl HAP.ValueStore
  def get_value(opts) do
    GenServer.call(__MODULE__, {:get, opts})
  end

  @impl HAP.ValueStore
  def put_value(value, opts) do
    GenServer.call(__MODULE__, {:put, value, opts})
  end

  @impl GenServer
  def init(_) do
    {:ok, ref} = Circuits.I2C.open(@i2c_bus)
    # Home ourselves to fully open at startup
    {:ok, %{ref: ref, current: 50.0, target: 50.0, position_state: @stopped} |> seek()}
  end

  @impl GenServer
  def handle_call({:get, :current_position}, _from, %{current: current} = state) do
    {:reply, {:ok, round(current)}, state}
  end

  def handle_call({:get, :target_position}, _from, %{target: target} = state) do
    {:reply, {:ok, round(target)}, state}
  end

  def handle_call({:get, :position_state}, _from, %{position_state: position_state} = state) do
    {:reply, {:ok, position_state}, state}
  end

  def handle_call({:put, target, :target_position}, _from, state) do
    {:reply, :ok, state |> Map.put(:target, target / 1) |> seek()}
  end

  def handle_call({:put, true, :hold_position}, _from, %{current: current} = state) do
    {:reply, :ok, state |> Map.put(:target, current) |> seek()}
  end

  def handle_call({:put, false, :hold_position}, _from, state) do
    {:reply, :ok, state}
  end

  @impl GenServer
  def handle_info(:move, state) do
    {:noreply, state |> seek()}
  end

  defp seek(%{ref: ref, current: current, target: target, position_state: position_state} = state) do
    desired_state =
      cond do
        target == 0.0 && current <= 0.0 -> @stopped
        target == 100.0 && current >= 100.0 -> @stopped
        current - target > 5 -> @closing
        current - target < -5 -> @opening
        true -> @stopped
      end

    Logger.info("state: #{position_state}, #{desired_state}. position: #{current}, #{target}")

    case {position_state, desired_state} do
      {@closing, @closing} ->
        # Don't change our controls, but update position & reschedule
        Process.send_after(self(), :move, 1000)
        %{state | current: current - @percent_per_second}

      {@opening, @opening} ->
        # Don't change our controls, but update position & reschedule
        Process.send_after(self(), :move, 1000)
        %{state | current: current + @percent_per_second}

      {@stopped, @stopped} ->
        state

      {_, @closing} ->
        # Start to close & reschedule a position update
        Process.send_after(self(), :move, 1000)
        close(ref)
        %{state | position_state: @closing, current: current - @percent_per_second}

      {_, @opening} ->
        # Start to open & reschedule a position update
        Process.send_after(self(), :move, 1000)
        open(ref)
        %{state | position_state: @opening, current: current + @percent_per_second}

      {_, @stopped} ->
        # Only stop movement if we're in the middle somewhere. Otherwise let the 
        # blind run to completion so we don't stop a tiny bit short of the end point
        if target != 0.0 && target != 100.0, do: hold(ref)

        # Mark ourselves as having reached our target in any case
        %{state | position_state: @stopped, current: target}
    end
  end

  # Button manipulation

  def open(ref) do
    Logger.info("Tapping open")
    tap_button(ref, @open_button_pressed)
  end

  def close(ref) do
    Logger.info("Tapping close")
    tap_button(ref, @close_button_pressed)
  end

  def hold(ref) do
    Logger.info("Tapping hold")
    tap_button(ref, @stop_button_pressed)
  end

  defp tap_button(ref, pin, duration \\ 250) do
    Circuits.I2C.write(ref, @i2c_device, <<0x00, pin>>)
    Process.sleep(duration)
    Circuits.I2C.write(ref, @i2c_device, <<0x00, @no_buttons_pressed>>)
    Process.sleep(duration)
    Circuits.I2C.write(ref, @i2c_device, <<0x00, pin>>)
    Process.sleep(duration)
    Circuits.I2C.write(ref, @i2c_device, <<0x00, @no_buttons_pressed>>)
  end
end

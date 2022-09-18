defmodule HAPBox.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    opts = [strategy: :one_for_one, name: HAPBox.Supervisor]

    hap_server_config = %HAP.AccessoryServer{
      name: "HAPBox Gateway",
      identifier: "17:f5:6b:21:a9:0e",
      accessory_type: 2,
      accessories: [
        %HAP.Accessory{
          name: "Skylight Blinds",
          services: [
            %HAP.Services.WindowCovering{
              current_position: {HAPBox.WindowCovering, :current_position},
              target_position: {HAPBox.WindowCovering, :target_position},
              position_state: {HAPBox.WindowCovering, :position_state},
              hold_position: {HAPBox.WindowCovering, :hold_position}
            }
          ]
        }
      ]
    }

    children = [
      HAPBox.WindowCovering,
      {HAP, hap_server_config}
    ]

    Supervisor.start_link(children, opts)
  end
end

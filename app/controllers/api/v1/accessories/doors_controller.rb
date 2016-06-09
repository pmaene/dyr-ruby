class Api::V1::Accessories::DoorsController < Api::V1::AccessoriesController
    skip_before_action :doorkeeper_authorize!, only: :nonce

    before_action :check_access, only: [:create, :update, :destroy]
    before_action :set_door, except: :nonce

    def nonce
        door = resource_class.find_by name: params[:name]
        render :json => {'nonce' => ('0x%08x' % door.nonce(false))}
    end

    def switch
        if @door.nil?
            Redis.current.set 'door', params[:id], options = {:ex => 10}

            @door = resource_class.find params[:id]
            @door.switch

            Event.create!(
                :user      => current_resource_owner,
                :accessory => @door
            )

            Redis.current.del 'door'

            render :json => {'status' => 'success'}
        else
            render :json => {'status' => 'busy'}
        end
    end

    protected

        def door_params
            params.permit :description, :name, :url
        end

        def query_params
            params.permit :user, :resource
        end

        def set_door
            if Redis.current.exists 'door'
                @door = resource_class.find Redis.current.get('door')
            end
        end

end

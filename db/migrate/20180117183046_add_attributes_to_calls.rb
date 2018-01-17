class AddAttributesToCalls < ActiveRecord::Migration[5.1]
  def change
    add_column :calls, :provider,      :string

    add_column :calls, :from,          :string
    add_column :calls, :to,            :string
    add_column :calls, :account_sid,   :string
    add_column :calls, :call_sid,      :string
    add_column :calls, :call_status,   :string
    add_column :calls, :from_city,     :string
    add_column :calls, :call_duration, :string
    add_column :calls, :voicemail_url, :string
  end
end

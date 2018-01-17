class Call < ApplicationRecord
  validates_presence_of :provider,
                        :from,
                        :to,
                        :call_status,
                        :call_sid,
                        :account_sid
end

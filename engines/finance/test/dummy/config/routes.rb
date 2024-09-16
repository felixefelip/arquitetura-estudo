Rails.application.routes.draw do
  mount Finance::Engine => "/finance"
end

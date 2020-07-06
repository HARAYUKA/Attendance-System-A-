Rails.application.routes.draw do
  root 'static_pages#top'
  get '/signup', to: 'users#new'
  
  # ログイン機能
  get    '/login', to: 'sessions#new'
  post   '/login', to: 'sessions#create'
  delete '/logout', to: 'sessions#destroy'
  
  resources :users do
     member do
      get 'edit_basic_info'
      patch 'update_basic_info'
      get 'confirm_one_month' # 勤怠変更申請送信
      get 'instructor_apploval' # 所属長承認ボタン
      get 'attendances/edit_one_month' # 1ヶ月の勤怠編集
      patch 'attendances/update_one_month' # 1ヶ月の勤怠更新
    end
    resources :attendances, only: :update do
      member do
        get 'edit_overwork_request' # 残業申請モーダル表示
        patch 'update_overwork_request' # 残業申請モーダル更新
      end
      collection do
        get 'edit_notice_overwork' # 残業申請お知らせモーダル表示
        patch 'update_notice_overwork' # 残業申請お知らせモーダル更新
        get 'change_att_request' # 勤怠変更申請モーダル表示
        patch 'update_att_request' # 勤怠変更申請モーダル更新
      end
    end
  end
end
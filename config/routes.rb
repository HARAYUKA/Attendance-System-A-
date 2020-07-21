Rails.application.routes.draw do
  get 'bases/index'

  root 'static_pages#top'
  get '/signup', to: 'users#new'
  
  # ログイン機能
  get    '/login', to: 'sessions#new'
  post   '/login', to: 'sessions#create'
  delete '/logout', to: 'sessions#destroy'
  
  # 拠点情報
  resources :bases
  
  resources :users do
    collection { post :import}
    member do
      get 'edit_basic_info' # 基本情報編集
      patch 'update_basic_info' # 基本情報更新
      get 'confirm_one_month' # 勤怠確認ボタン
      patch 'superior_apploval' # 所属長承認ボタン
      get 'attendances/edit_one_month' # 1ヶ月の勤怠編集
      patch 'attendances/update_one_month' # 1ヶ月の勤怠更新
      get 'attendance_log' # 勤怠ログ
    end
    collection do
      get 'working_members' # 出勤中社員一覧
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
        get 'edit_monthly' # 1ヶ月勤怠申請モーダル表示
        patch 'update_monthly' # 1ヶ月勤怠申請モーダル更新
      end
    end
  end
end
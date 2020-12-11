RankmiExcelReview::Engine.routes.draw do
    resources :review , only:[:index, :create]
    resources :test, only:[:index]
end

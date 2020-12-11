RankmiExcelReview::Engine.routes.draw do
    resources :review , only:[:index, :create] do 
        collection do
            post :index
        end
    end
    resources :test, only:[:index]
end

module RankmiExcelReview
    class HamzaController < ApplicationController 
        layout 'application'
        require 'byebug'
        def index
            # RankmiExcelReview::Main.greet
            byebug
            @s=params.to_s
        end
    end
end

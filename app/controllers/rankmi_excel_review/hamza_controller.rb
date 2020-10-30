module RankmiExcelReview
    class HamzaController < ApplicationController 
        layout 'application'
        require 'byebug'
        def index
            # RankmiExcelReview::Main.greet
            @s=params.to_s
        end
    end
end

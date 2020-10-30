module RankmiExcelReview
    class HamzaController < ApplicationController 
        layout 'application'
        require 'byebug'
        def index
            # RankmiExcelReview::Main.greet
            puts params
        end
    end
end

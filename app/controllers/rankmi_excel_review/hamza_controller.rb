module RankmiExcelReview
    class HamzaController < ApplicationController 
        layout 'application'
        require 'byebug'
        def index
            @input_file = RubyXL::Parser.parse(params[:path_to_file]) 
            @s=@input_file[0][0][0]
        end
    end
end

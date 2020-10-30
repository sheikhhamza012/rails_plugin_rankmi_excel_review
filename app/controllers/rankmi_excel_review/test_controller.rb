module RankmiExcelReview
    class TestController < ApplicationController 
        require 'byebug'
        def index
            redirect_to review_index_path(:path_to_file=>"../../excel.xlsx",:redirect_to=>test_path(1))
        end
        def show

        end
    end
end

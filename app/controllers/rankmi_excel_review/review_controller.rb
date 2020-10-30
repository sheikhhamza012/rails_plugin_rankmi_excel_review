module RankmiExcelReview
    class ReviewController < ApplicationController 
        require 'byebug'
        require 'rubyXL/convenience_methods/cell'

        layout 'application'
        helper_method :selected

        def index
            @input_file = RubyXL::Parser.parse(params[:path_to_file]) 
            @rankmi_sheet=@input_file[1]
            @input_sheet=@input_file[0]
        end
        def create
            @input_file = RubyXL::Parser.parse(params[:path_to_file])
            @new_values = params[:column_numbers]
            @new_values.keys().each do |i|
                if !@new_values[i]&.empty?
                    change_to = @new_values[i]
                    if @new_values[i]=="optional"
                        change_to= "optional_"+@input_file[0][0][i.to_i]&.value&.split('_')&.last
                    end
                    @input_file[0][0][i.to_i].change_contents(change_to)
                end
            end
            @input_file[0].add_cell(0,@input_file[0][0].size,"Comentario revisión")
            @input_file.write(params[:path_to_file])
            redirect_to params[:redirect_to]
        end
        def selected(input, option)
            input=input&.downcase
            option=option&.downcase
            if input==option || ( input.include?("genero") && option=="gender" ) || ( ( input.include?("optional_" ) || input.include?("opcional_" ) ) && option=="optional" )
                "selected"
            end
        end
    end
end

module RankmiExcelReview
    class ReviewController < ApplicationController 
        require 'byebug'
        require 'rubyXL'
        require 'rubyXL/convenience_methods/cell'
        require 'open-uri'

        layout 'application'
        helper_method :selected
        
        # action to show the table (form) for review
        def index
            @input_file = RubyXL::Parser.parse(open(params[:path_to_file])) 
            @rankmi_sheet=@input_file[1]
            @input_sheet=@input_file[0]
        end

        # method to add cell or edit if it exists 
        def print_warning(file,row,col,val)
            if file[row][col]&.value.to_s.empty?
                file&.add_cell(row,col,val) 
            else
                file[row][col]&.change_contents("#{file[row][col]&.value}, #{val}") 
            end

        end

        # if a column exists return index else create it and return index
        def create_column_and_return_index(file, name)
            col_index=find_col(file, name)
            return col_index if col_index
            i=file[0]&.size
            return nil if !i
            print_warning(file,0,i,name.to_s)
            return i
        end

        #find a column with name and return index
        def find_col(file, name)
            i=0
            found=nil
            while i<file[0]&.size.to_i
                cell = file[0][i]
                if cell&.value==name
                    found=i
                    break
                end
                i+=1
            end
            return found
            
        end

        #find a row index in a column_name
        def find_row(file,column_name,value,curr_col)
            i=0
            found = nil
            column_index = create_column_and_return_index(file, column_name)
            while i < file.sheet_data.rows.size 
                break if !column_index
                if file[i][column_index]&.value.to_s&.downcase == value.to_s&.downcase && curr_col!=i
                    found=i
                    break
                end
                i+=1
            end
            return found
        end

        #index of column name with a key string in it
        def col_index_containing_key_in_name(file, key)
            i=0
            found=[]
            while i<file[0]&.size
                cell = file[0][i]
                if cell&.value&.include?(key)
                    found<<i
                end
                i+=1
            end
            return found
        end

        #if a coulmn has "_#"
        def has_underscore_number?(key)
            if key&.include?("_") && key&.split('_')&.last=~/^(\d)+$/
                return true
            end
            return false
        end
        #upload
        def upload(stream)
            s3 = Aws::S3::Resource.new
            key = "#{Time.now.to_i.to_s}.xlsx"
            obj = s3.bucket(ENV['AWS_BUCKET']).object(key)
            # obj.upload_file(file.to_io)
            obj.put(body: stream)
            return obj.public_url
        end
        # post of the edit form is recieved here
        def create
            #create files
            @input_file = RubyXL::Parser.parse(open(params[:path_to_file]))
            @BBDD_rankmi_file = RubyXL::Workbook.new
            @no_existe_BBDD_file = RubyXL::Workbook.new

            #get the post data that has the values from dropdown for the columns that needs changing of names
            @new_values = params[:column_numbers]

            #create new feedback columns
            comment_col = create_column_and_return_index(@input_file[0],"Comentario revisión")
            gender_col = create_column_and_return_index(@input_file[0],"revisión género")
            comparison_col = create_column_and_return_index(@input_file[0],"comentario comparación")
            rankmi_email_col = create_column_and_return_index(@input_file[0],"email en Rankmi")
            rankmi_username_col = create_column_and_return_index(@input_file[0],"username en Rankmi")
            no_user_col = create_column_and_return_index(@input_file[0],"usuario nuevo")
            
            puts "Writing to file..."
            
            #for row
            @input_file[0].each_with_index do |row, ind|
                puts ind.to_s+" :row"
                i= 0
                
                #for cell in row
                while i<@input_file[0][0]&.size
                    cell= row[i]

                    #transform header
                    if ind == 0
                        header = @input_file[0][0][i]&.value
                        if !@new_values[i.to_s]&.empty?
                            change_to = @new_values[i.to_s]
                            if @new_values[i.to_s]&.downcase=="optional"
                                change_to= "optional_"+cell&.value&.split('_')&.last
                            end
                            cell&.change_contents(change_to)
                        end
                    end

                    #make cell printable
                    if cell&.value.class == String
                        cell&.change_contents(cell&.value&.strip&.gsub(/\s+/, " ")&.gsub(/[^[:print:]]/,''))
                    end


                    #convert to lowercase 
                   if (%w[IDENTIFIER USERNAME MANAGER_IDENTIFIER RUT GENDER].include?(@input_file[0][0][i]&.value&.upcase) || @input_file[0][0][i]&.value&.split('_')&.last=~/^(\d)+$/) && cell&.value.class==String
                        
                        cell&.change_contents(cell&.value&.downcase)


                    end

                    # add comment if email is invalid, convert special chars to ascii 
                    if @input_file[0][0][i]&.value&.downcase == "email" && ind !=0
                        cell&.change_contents(cell&.value&.unicode_normalize(:nfd).gsub(/[\u0300-\u036F]/, '')&.downcase)
                        email_reg_ex=/^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/
                        if !cell&.value.to_s&.empty? && !(cell&.value =~ email_reg_ex)
                            # col = create_column_and_return_index(@input_file[0],"Comentario revisión")
                            print_warning(@input_file[0],ind,comment_col,"revisar correo")
                        end

                    end

                    #remove underscore from fcompetences
                    if @input_file[0][0][i]&.value&.downcase == "fcompetences" && ind !=0
                        cell&.change_contents(cell&.value&.gsub(/_+/,""))

                    end
                    
                    #change - to / in dates
                    if (@input_file[0][0][i]&.value&.downcase == "joiningdate" ||  @input_file[0][0][i]&.value&.downcase == "birthdate") && ind !=0 && !cell&.value.to_s.empty?
                        cell&.change_contents(Date.parse(cell&.value&.to_s)&.strftime("%d/%m/%Y"))

                    end
                    
                    #validate gender to be m,f
                    if @input_file[0][0][i]&.value&.downcase == "gender" && ind !=0 && !(cell&.value&.downcase=='f' || cell&.value&.downcase=='m')
                        # col = create_column_and_return_index(@input_file[0],"revisión género")
                        print_warning(@input_file[0],ind,gender_col,"revisar género")

                    end
                    
                    # area should always exist
                    if @input_file[0][0][i]&.value&.downcase == "area" && ind !=0 && cell&.value.to_s.empty?
                        # col = create_column_and_return_index(@input_file[0],"Comentario revisión")
                        print_warning(@input_file[0],ind,comment_col,"usuario sin área")

                    end

                    # identifier should exist
                    if @input_file[0][0][i]&.value&.downcase == "identifier" && ind !=0 && cell&.value.to_s.empty?
                        # col = create_column_and_return_index(@input_file[0],"Comentario revisión")
                        print_warning(@input_file[0],ind,comment_col,"identifier vacío")

                    end
                   
                    # duplicate email shouldnt  exist
                    if @input_file[0][0][i]&.value&.downcase == "email" && ind !=0 && !cell&.value.to_s.empty? && find_row(@input_file[0],"email",cell&.value&.to_s,ind)
                        # col = create_column_and_return_index(@input_file[0],"Comentario revisión")
                        print_warning(@input_file[0],ind,comment_col,"correo duplicado")

                    end

                    # duplicate identifier shouldnt  exist
                    if @input_file[0][0][i]&.value&.downcase == "identifier" && ind !=0 && !cell&.value.to_s.empty? && find_row(@input_file[0],"identifier",cell&.value&.to_s,ind)
                        # col = create_column_and_return_index(@input_file[0],"Comentario revisión")
                        print_warning(@input_file[0],ind,comment_col,"identifier duplicado")

                    end

                    # duplicate username shouldnt  exist
                    if @input_file[0][0][i]&.value&.downcase == "username" && ind !=0 && !cell&.value.to_s.empty? && find_row(@input_file[0],"username",cell&.value&.to_s,ind)
                        # col = create_column_and_return_index(@input_file[0],"Comentario revisión")
                        print_warning(@input_file[0],ind,comment_col,"username duplicado")

                    end

                    # checks if identifier exist in rankmi sheet copies email and username from rankmi and add comment if username or email from rankmi is different
                    if @input_file[0][0][i]&.value&.downcase == "identifier" && ind !=0 && !cell&.value.to_s.empty? 
                        found_row = find_row(@input_file[1],"identifier",cell&.value,-1)
                        if found_row
                            index_of_rankmi_email = find_col(@input_file[1],"email")
                            if index_of_rankmi_email
                                print_warning(@input_file[0],ind,rankmi_email_col,@input_file[1][found_row][index_of_rankmi_email]&.value)
                                
                                curr_email_col = find_col(@input_file[0],"email")
                                
                                if curr_email_col && @input_file[1][found_row][index_of_rankmi_email]&.value&.strip&.gsub(/\s+/, " ")&.gsub(/[^[:print:]]/,'')&.unicode_normalize(:nfd).gsub(/[\u0300-\u036F]/, '')&.downcase != @input_file[0][ind][curr_email_col]&.value&.strip&.gsub(/\s+/, " ")&.gsub(/[^[:print:]]/,'')&.unicode_normalize(:nfd).gsub(/[\u0300-\u036F]/, '')&.downcase
                                    # byebug
                                    print_warning(@input_file[0],ind,comparison_col,"otro correo en Rankmi")
        
                                end
                            end
                            index_of_rankmi_username =  find_col(@input_file[1],"username")
                            if index_of_rankmi_username
                                print_warning(@input_file[0],ind,rankmi_username_col,@input_file[1][found_row][index_of_rankmi_username]&.value)
                                
                                curr_username_col = find_col(@input_file[0],"username")
                                if curr_username_col && @input_file[1][found_row][index_of_rankmi_username]&.value&.strip&.gsub(/\s+/, " ")&.gsub(/[^[:print:]]/,'')&.downcase != @input_file[0][ind][curr_username_col]&.value&.strip&.gsub(/\s+/, " ")&.gsub(/[^[:print:]]/,'')&.downcase
                                    print_warning(@input_file[0],ind,comparison_col,"otro username en Rankmi")
        
                                end
                            end
                            
                        else
                            print_warning(@input_file[0],ind,no_user_col,"x")
                        end

                        #check if duplicate email or usename exists for other identifier
                        curr_row_email = @input_file[0][ind][find_col(@input_file[0],"email")]&.value
                        duplicate_email = find_row(@input_file[1],"email",curr_row_email,found_row)
                        if duplicate_email
                            print_warning(@input_file[0],ind,comparison_col,"correo pertenece a otro usuario (#{@input_file[1][duplicate_email][find_col(@input_file[1],"identifier")]&.value})")
                        end
                       
                        curr_row_username = @input_file[0][ind][find_col(@input_file[0],"username")]&.value
                        duplicate_username = find_row(@input_file[1],"username",curr_row_username,found_row)
                        if duplicate_username
                            print_warning(@input_file[0],ind,comparison_col,"usuario pertenece a otro usuario (#{@input_file[1][duplicate_username][find_col(@input_file[1],"identifier")]&.value})")
                        end
                    end

                    #checks autoevaluacion is x then ponderation_autoevaluation shouldnt be empty
                    if @input_file[0][0][i]&.value&.downcase == "autoevaluacion" && ind !=0 && !cell&.value.to_s.empty? && cell&.value == "x"
                        col = find_col(@input_file[0],"ponderation_autoevaluation")
                        if col && @input_file[0][ind][col]&.value.to_s.empty?
                            print_warning(@input_file[0],ind,comment_col,"revisar ponderaciones")
                        end
                        
                    end
                        
                    #creates BBDD_rankmi_file and no_existe_BBDD_file 
                    if (["validator", "second_validator", "verifier"].include?(@input_file[0][0][i]&.value&.downcase) || has_underscore_number?(@input_file[0][0][i]&.value&.downcase)) && ind !=0 && !cell&.value.to_s.empty? 
                        # byebug
                        found_row = find_row(@input_file[0],"identifier",cell&.value,-1)
                        if !found_row
                            found_row = find_row(@input_file[1],"identifier",cell&.value,-1)
                            if found_row
                                validator_header_index = 0
                                size=@BBDD_rankmi_file[0].sheet_data.rows.size
                                row_exists = find_row(@BBDD_rankmi_file[0],"identifier",cell&.value,-1)
                                if !row_exists
                                    while validator_header_index < @input_file[1][0].size
                                        @BBDD_rankmi_file[0].add_cell(0, validator_header_index, @input_file[1][0][validator_header_index]&.value)
                                        @BBDD_rankmi_file[0].add_cell(size==0 ? 1 : size, validator_header_index, @input_file[1][found_row][validator_header_index]&.value)
                                        validator_header_index+=1
                                    end
                                end
                            else 
                                row_exists = find_row(@no_existe_BBDD_file[0],"identifier",cell&.value,-1)
                                if !row_exists
                                    @no_existe_BBDD_file[0].add_cell(0,0,"identifier")
                                    @no_existe_BBDD_file[0].add_cell(0,1,"comentario")
                                    size=@no_existe_BBDD_file[0].sheet_data.rows.size
                                    @no_existe_BBDD_file[0].add_cell(size ,0,cell&.value)
                                    msg = "Validador no existe en BBDD"
                                    if has_underscore_number?(@input_file[0][0][i]&.value&.downcase)
                                        msg = "Evaluator no existe en BBDD"
                                    elsif @input_file[0][0][i]&.value&.downcase == "verifier"
                                        msg = "Verificador no existe en BBDD"
                                    end
                                    @no_existe_BBDD_file[0].add_cell( size,1,msg)
                                end
                            end
                        elsif found_row == ind && !has_underscore_number?(@input_file[0][0][i]&.value&.downcase)
                            print_warning(@input_file[0],ind,comment_col,"el evaluado no puede ser su propio validador")
                            
                        end
                    
                    end


                    i+=1
                end

                #ponderations cols should have 100 sum
                cols_having_ponderation = col_index_containing_key_in_name(@input_file[0], "ponderation_")
                if  cols_having_ponderation.size > 0 && ind!=0
                    sum=0
                    cols_having_ponderation.each do |key|
                        sum+=@input_file[0][ind][key]&.value.to_i
                    end
                    if sum !=100 && sum !=0
                        print_warning(@input_file[0],ind,comment_col,"la ponderación no suma 100%")
                    end
                end
            end

            #add header values for new cols
            print_warning(@input_file[0],0,comment_col,"Comentario revisión")
            print_warning(@input_file[0],0,gender_col,"revisión género")
            print_warning(@input_file[0],0,comparison_col,"comentario comparación")
            print_warning(@input_file[0],0,rankmi_email_col,"email en Rankmi")
            print_warning(@input_file[0],0,rankmi_username_col,"username en Rankmi")
            print_warning(@input_file[0],0,no_user_col,"usuario nuevo")
            
            #save the files
            input_file_url = params[:path_to_file]
            edited_input_file_url = upload(@input_file.stream)
            output_BBDD_rankmi_file_url = upload(@BBDD_rankmi_file.stream)
            output_no_existe_BBDD_file_url = upload(@no_existe_BBDD_file.stream)
            # @input_file.write(params[:path_to_file])
            # @BBDD_rankmi_file.write("En BBDD rankmi a agregar.xlsx")
            # @no_existe_BBDD_file.write("No existe en BBDD.xlsx")

            redirect_to "#{params[:redirect_to]}/?input_file_url=#{input_file_url}&edited_input_file_url=#{edited_input_file_url}&output_BBDD_rankmi_file_url=#{output_BBDD_rankmi_file_url}&output_no_existe_BBDD_file_url=#{output_no_existe_BBDD_file_url}"
        end

        #check which checkbox value should be selected
        def selected(input, option)
            input=input&.downcase
            option=option&.downcase
            if input==option || ( input.include?("genero") && option=="gender" ) || ( ( input.include?("optional_" ) || input.include?("opcional_" ) ) && option=="optional" )
                "selected"
            end
        end
    end
end

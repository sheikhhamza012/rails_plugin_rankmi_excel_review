module RankmiExcelReview
require "byebug"
require 'rails_helper'
    RSpec.describe ReviewController, :type=>:feature do
        it "check and copy the input file" do 
            FileUtils.cp("excel_files/excel_copy.xlsx", "excel_files/excel.xlsx")
            expect(File.exist?("excel_files/excel.xlsx")).to eq(true)
        end
        it "pass the file and check if form appears" do
            visit '/rankmi_excel_review/review?path_to_file=excel_files%2Fexcel.xlsx'
            expect(page).to have_content("identifier")
        end

        it "submit the form " do
            visit '/rankmi_excel_review/review?path_to_file=excel_files%2Fexcel.xlsx&redirect_to=%2Frankmi_excel_review%2Ftest'
            click_on "Revisar Excel"
            expect(page).to have_content("written")
        end
        it "check the two new files exist" do 
            expect(File.exist?("En BBDD rankmi a agregar.xlsx")).to eq(true)
            expect(File.exist?("No existe en BBDD.xlsx")).to eq(true)
        end
        it "Match the contents for excel file" do 
            expected = RubyXL::Parser.parse('excel_files/excel_expect.xlsx')
            output = RubyXL::Parser.parse('excel_files/excel.xlsx')
            expected[0].each_with_index do |expected_val, i|
                rows= expected[0][0].size
                j=0
                while j<rows do
                    expect(expected_val[j]&.value).to eq(output[0][i][j]&.value)
                    j+=1
                end
            end
        end
        it "Match the contents for En BBDD file" do 
            expected = RubyXL::Parser.parse('excel_files/BBDD_expect.xlsx')
            output = RubyXL::Parser.parse('En BBDD rankmi a agregar.xlsx')
            expected[0].each_with_index do |expected_val, i|
                rows= expected[0][0].size
                j=0
                while j<rows do
                    expect(expected_val[j]&.value).to eq(output[0][i][j]&.value)
                    j+=1
                end
            end
        end
        it "Match the contents for No BBDD file" do 
            expected = RubyXL::Parser.parse('excel_files/No_BBDD_expect.xlsx')
            output = RubyXL::Parser.parse('No existe en BBDD.xlsx')
            expected[0].each_with_index do |expected_val, i|
                rows= expected[0][0].size
                j=0
                while j<rows do
                    expect(expected_val[j]&.value).to eq(output[0][i][j]&.value)
                    j+=1
                end
            end
        end
        it "Clean up files" do 
            a = 'No existe en BBDD.xlsx'
            b = 'En BBDD rankmi a agregar.xlsx'
            c = 'excel_files/excel.xlsx'
            File.delete(a) if File.exists? a
            expect(File.exist?(a)).to eq false
            File.delete(b) if File.exists? b
            expect(File.exist?(b)).to eq false
            File.delete(c) if File.exists? c
            expect(File.exist?(c)).to eq false
        end
    end
end
require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'time'

#Gets first name column, ignoring header
=begin 
lines = File.readlines('event_attendees.csv')
lines.each do |line|
    next if line == " ,RegDate,first_Name,last_Name,Email_Address,HomePhone,Street,City,State,Zipcode\n"
    columns = line.split(',')
    name = columns[2]
    puts name
end 
=end

#Better Method
=begin 
lines = File.readlines('event_attendees.csv')
lines.each_with_index do |line, idx|
    next if idx == 0
    columns = line.split(",")
    name = columns[2]
    puts name
end
=end

#Using CSV library
=begin 
contents = CSV.open('event_attendees.csv', headers: true)
contents.each do |row|
    name = row[2]
    puts name
end
=end

#Accessing columns by their names

def legislators_by_zipcode(zip)
    civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
    civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

    begin
        civic_info.representative_info_by_address(
            address: zip,
            levels: 'country',
            roles: ['legislatorUpperBody', 'legislatorLowerBody']
        ).officials
        #legislators = legislators.officials
        #legislator_names = legislators.map do |legislator|
        #    legislator.name
        #end
        #legislators_string = legislator_names.join(", ")
    rescue
        "You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials"
    end
end

def clean_zipcode(zipcode)
=begin 
    if zipcode.nil?
        zipcode = "00000"
    elsif zipcode.length < 5
        zipcode = zipcode.rjust(5, '0') #adds 5 spaces and fills in empty with 0
    elsif zipcode.length > 5
        zipcode = zipcode[0..4] #String#slice()
    else 
        zipcode
    end
=end
    zipcode.to_s.rjust(5,'0')[0..4]
end

def clean_phone_num(phone_num)
    phone_num = phone_num.to_s.tr('^0-9', '')
    if phone_num.length < 10
       phone_num = "Invalid"         
    elsif phone_num.length == 11 
        if phone_num[0] == "1"
            phone_num[0] = ''
            phone_num
        else
            phone_num = "Invalid"
        end
    elsif phone_num.length > 11
        phone_num = "Invalid" 
    else
        phone_num
    end
end

def get_time(time)
    times = Time.strptime(time, '%m/%d/%y %k:%M')
    times
end

def time_to_date(times)
    dates = Date.parse(times.to_s)
    dates
end

def get_hour(times)
    hours = times.hour
    hours
end

def get_wkdays(dates)
    wkday = dates.wday
    wkday
end

def find_avg_hour(a)
    avg = a.sum / a.size
    avg
end

def hash_for_mode(a)
    hash = Hash.new(0)
    a.each do |i|
      hash[i]+=1
    end
    mode = largest_hash_key(hash)
    mode
end

def largest_hash_key(hash)
    max = hash.max_by(2){|k,v| v }
    return "First Popular: #{max[0][0]}, Second Popular: #{max[1][0]}"
end

def wday_to_dayname(wkday)
    dayname = wkday.strftime("%A")
    dayname
end

def save_thank_you_letter(id, form_letter)
    Dir.mkdir('output') unless Dir.exist?('output')
    filename = "output/thanks_#{id}.html"

    File.open(filename, 'w') do |file|
        file.puts form_letter
    end
end

def open_csv
    CSV.open(
    'event_attendees.csv', 
    headers: true, 
    header_converters: :symbol
)
end

def run_event_man
    puts "Event Manager Initialized!\n\n"

    contents = open_csv

    template_letter = File.read('form_letter.erb') #form_letter.html
    erb_template = ERB.new(template_letter)

    hour_list = []
    wkday_list = []

    contents.each do |row|
        id = row[0]
        name = row[:first_name]
        phone_num = clean_phone_num(row[:homephone])

        time = get_time(row[:regdate])
        date = time_to_date(time)

        daynames = wday_to_dayname(date)
        wkdays = get_wkdays(date)
        hour = get_hour(time)
        wkday_list = wkday_list.push(daynames)
        hour_list = hour_list.push(hour)

        zipcode = clean_zipcode(row[:zipcode])

        legislators = legislators_by_zipcode(zipcode)

        #personal_letter = template_letter.gsub('FIRST_NAME', name)
        #personal_letter.gsub!('LEGISLATORS', legislators)

        form_letter = erb_template.result(binding)
        
        puts "#{name} - #{phone_num}"

        save_thank_you_letter(id, form_letter)

        #puts "#{name} - #{zipcode} - Legislators: #{legislators}"
        #puts personal_letter
    end

    avg_hour = find_avg_hour(hour_list)
    mode_hour = hash_for_mode(hour_list)
    mode_day = hash_for_mode(wkday_list)

    puts "Average hour is #{avg_hour}"
    p "Popular Hours | #{mode_hour}"

    p "Popular Days | #{mode_day}"
end

run_event_man
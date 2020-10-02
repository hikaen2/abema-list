#! /usr/bin/env ruby
# coding: utf-8

require 'dotenv'
require 'erb'
require 'json'
require 'open-uri'

def main
  Dotenv.load

  jwt  = ENV['JWT']
  ua   = 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/77.0.3865.90 Safari/537.36'
  from = (Date.today - 7).strftime('%Y%m%d')
  to   = (Date.today + 7).strftime('%Y%m%d')
  json = JSON.parse(open("https://api.abema.io/v1/media?dateFrom=#{from}&dateTo=#{to}", 'User-Agent' => ua, 'Authorization' => "bearer #{jwt}").read, symbolize_names: true)

  # slots = json[:channelSchedules].map{|channel| channel[:slots]}.flatten
  # slots.select{|slot| slot[:channelId].include?('anime') }.select{|slot| slot[:flags][:timeshiftFree] }.sort_by{|slot| slot[:title].sub(/^【.+?】/, '') }.group_by{|slot| slot[:displayProgramId]}.map{|k,v| v}.each do |group|
  #   slot = group.first
  #   #puts "%s\t%s\t%s\t%s\thttps://abema.tv/channels/%s/slots/%s\t%s" % [Time.at(slot[:startAt]), Time.at(slot[:endAt]), (Time.at(slot[:endAt]) - Time.at(slot[:startAt])) / 60, Time.at(slot[:timeshiftFreeEndAt]), slot[:channelId], slot[:id], slot[:title], ]
  # end

  slots = json[:channelSchedules].map{|channel| channel[:slots]}.flatten.select{|slot| slot[:channelId].include?('anime') and slot[:flags][:timeshiftFree] and Time.at(slot[:timeshiftFreeEndAt]) >= Date.today.to_time }.sort_by{|slot| slot[:title]}

  puts ERB.new(DATA.read, nil, '-').result(binding)
end

main

__END__
<!doctype html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
  <meta name="referrer" content="no-referrer">
  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/twitter-bootstrap/4.5.2/css/bootstrap.css">
  <link rel="stylesheet" href="https://cdn.datatables.net/1.10.22/css/jquery.dataTables.min.css">
  <script src="https://code.jquery.com/jquery-3.5.1.js"></script>
  <script src="https://cdn.datatables.net/1.10.22/js/jquery.dataTables.min.js"></script>
</head>
<body>
  <main class="container">
    <table id="table1" class="display compact">
      <thead>
        <tr>
          <th>title</th>
          <th>min</th>
          <th>start at</th>
          <th>timeshift end at</th>
        </tr>
      </thead>
      <tbody>
        <%- slots.each do |slot| -%>
        <tr>
          <td><a href="<%= "https://abema.tv/channels/%s/slots/%s" % [slot[:channelId], slot[:id]] %>"><%= slot[:title].sub(/^【.+?】/, '') %></a></td>
          <td><%= (Time.at(slot[:endAt]) - Time.at(slot[:startAt])).to_i / 60 %></td>
          <td><%= Time.at(slot[:startAt]).strftime('%Y-%m-%d %H:%M') %></td>
          <td><%= Time.at(slot[:timeshiftFreeEndAt]).strftime('%Y-%m-%d %H:%M') %></td>
        </tr>
        <%- end -%>
      </tbody>
    </table>
  </main>
  <script>
    $(document).ready( function () {
      $('#table1').DataTable({
        "paging": false
      });
    });
  </script>
</body>
</html>

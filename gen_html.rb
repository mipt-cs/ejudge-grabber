#!/usr/bin/ruby
#encoding: UTF-8

require './judge.rb'

students = [
  {
    name: 'Имя По Русски для html вывода',
    variants: ['имена', 'в', 'поле', 'участник']
  },

  {
    name: 'Петр',
    variants: ['Петров Петр Петрович', 'petya']
  },

  {
    name: 'Иван',
    variants: ['Иванов Иван Иванович']
  }
]


url = 'http://judge2.vdi.mipt.ru/cgi-bin/new-client' 

contests = [
  {url: url, contest_id: 730303},
  {url: url, contest_id: 730306},
]

h = {
  login: 'login',
  password: 'password'
}

name2student = {}
students.each do |s|
  s[:variants].each do |v|
    name2student[v] = s
  end
  
  s[:rate] = 0
  s[:n_solved] = 0
  s[:contests] = {}
end

contests = contests.map { |c| judge_get_results(h.merge(c)) }
contests.each { |c|
  c[:results].each { |r|
    s = name2student[r[:login]]
    if s.nil?
      STDERR.puts "Warning: unknown '#{r[:login]}' '#{r[:name]}' in contest '#{c[:name]}' is skipped"
      next
    end

    if s[:contests][c[:id]]
      STDERR.puts "Warning: several '#{s[:name]}' in contest '#{c[:name]}', '#{r[:name]}' is skipped"
      next
    end
    s[:contests][c[:id]] = r
    s[:rate] += r[:rate]
    s[:n_solved] += r[:n_solved]
  }
}


puts <<HTML
<style>
table {
  border-collapse: collapse;
}
td {
  border: 1px solid black;
}
th.rotate {
  height: 200px;
  white-space: nowrap;
  vertical-align: bottom;
}
th.rotate > div {
  transform: translate(1.1em, 0) rotate(-90deg);
  transform-origin: left bottom 0;
  width: 2em;
}
</style>
<table>
<tr>
<th></td>
<th class="rotate"><div><span>Solved</span></div></td>
<th class="rotate"><div><span>Total rate</span></div></td>
HTML
contests.each { |c|
  puts "<th class=rotate><div><span>#{c[:title]}</span></div></th>"
}
puts "</tr>"
students.sort_by{ |s| -s[:n_solved] }.each {|s|
  puts '<tr>'
  puts "<td>#{s[:name]}</td>"
  puts "<td>#{s[:n_solved]}</td>"
  puts "<td>#{s[:rate]}</td>"
  contests.each { |c|
    t = s[:contests][c[:id]]
    if t.nil?
      puts '<td></td>'
    else
      puts "<td>#{t[:n_solved]}</td>"
    end
  }
  puts '</tr>'
}
puts "</table>"

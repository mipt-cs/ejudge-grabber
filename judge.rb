#!/usr/bin/ruby
#encoding: UTF-8

require 'net/http'
require 'nokogiri'
require 'pp'

# dont forget login, password and contest_id =)
def judge_get(h = {})
  h = {
    role: 0,
    locale_id: 1,
    action: 94,
  }.merge(h)

  uri = URI(h[:url])
  #pp uri, h
  res = Net::HTTP.post_form(uri, h)
  #p res['set-cookie']

  headers = {
    'Cookie' => res['set-cookie'].split(';')[0]
  }

  uri = URI(res['location'])
  http = Net::HTTP.new(uri.host, uri.port)
  html = http.get(uri.path + '?' + uri.query.gsub(/action=\d+/, "action=#{h[:action]}"), headers)
  html.body.force_encoding('utf-8')
end

def judge_get_info(h = {})
  html = judge_get(h.merge({action: 2}))
  {
    id: h[:contest_id],
    name: html.match(/<title>[^\[]*\[([^\]]*)\]/)[1],
    problems: html[/probNavRightList.*/].scan(/(?:<a[^>]*>)([^<]*)(?:<\/a>)/).flatten
  }
end

def judge_get_results(h = {})
  html = judge_get(h.merge({action: 94}))
  page = Nokogiri::HTML(html)

  results = page.css('table.standings tr').map { |tr|
    tr.css('td')
  }[1..-4].map { |ar|
    {
      login: ar[1].text,
      name: ar[2].text,
      problems: ar[3..-3].map { |el|
        {
          solved: !!el.at_css('b'),
          val: el.text.to_i
        }
      },
      n_solved: ar[-2].text.to_i,
      rate: ar[-1].text.to_i
    }
  }

  {
    id: h[:contest_id],
    name: h[:name],
    title: (page.title.match(/\[([^\]]*)\]/)[1] rescue h[:contest_id]),
    problems: page.css('table.standings tr')[0].children[3..-3].map {|el| el.text},
    results: results
  }
end

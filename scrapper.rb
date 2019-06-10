require 'down'
require 'net/http'


def dl_page (link)
	Net::HTTP.get(URI(link))
end


def ext_link (page, link_head)
	link_head.each do |link|
		if page.index(link) != nil
			link_a = page.index(link)
			link_b = page.index('"', link_a)

			return page [ link_a .. link_b-1 ]
		end
	end

	nil
end


def dl_img (link, dst_path)
	Down.download(link, destination: dst_path)
end


def incr (uri, alph, num = 1)
	if uri == alph[alph.length-1] * uri.length
		puts "[!] #{uri} was last one. Exiting.."
		return nil
	end

	while num > 0
		uri_pos = uri.length-1
		alph_pos = alph.length-1

		while uri[uri_pos] == alph[alph_pos]
			uri[uri_pos] = alph[0]
			uri_pos -= 1
		end

		uri[uri_pos] = alph[ alph.index(uri[uri_pos]) + 1 ]
		
		num -= 1
	end
	
	uri
end


def thr_get_dl_link (dst_path, uri, uri_start, link_head, alph, dl_num)
	while dl_num > 0
		page = dl_page(uri + uri_start)
		link = ext_link(page, link_head)
		
		if link != nil
			dl_img(link, "#{dst_path}#{uri_start}.jpg")	
			puts "[+] Image #{uri_start}..OK"
		else
			puts "[-] Image #{uri_start}..FAILED"
		end

		incr(uri_start, alph)
		dl_num -= 1
	end
end


# tried to use x2 threads model:
#
# 1st is for finding dl links
# 2nd is for actual dl an image
#
# but got banned almost immediately

def thr_dl_img (link_pool, dst_path, thr_num)
	while link_pool.length > 0
		dl_data = link_pool.shift.split("_")
	
		dl_name = dl_data[0]
		dl_link = dl_data[1]

		dl_img(dl_link, dst_path + dl_name + ".jpg")
	end
end


##########################
# config vars
##########################

dst_path = "./"
thrs_num = 8
dl_per_thr = 32

uri_start = 'n00000'

##########################

uri = 'https://prnt.sc/'

alph = [ *('0'..'9'), *('a'..'z') ]
link_head = [ 'https://image.prntscr.com/image/', 'https://i.imgur.com/' ] 

thrs = []


(1..thrs_num).each do |thr_num|
	uri_curr = incr(uri_start.dup, alph, (thr_num-1) * dl_per_thr)

	thr_lnk = Thread.new { thr_get_dl_link(dst_path, uri, uri_curr, link_head, alph, dl_per_thr) }
	thrs.push(thr_lnk)
end


thrs.each_with_index do |thr, index|
	thrs[index].join
end

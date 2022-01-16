fx_version 'adamant'

game 'gta5'

description 'ESX Menu Default'

version 'legacy'
lua54 'yes'
use_fxv2_oal 'yes'

client_scripts {
	'client/main.lua'
}

ui_page {
	'html/ui.html'
}

files {
	'html/ui.html',
	'html/css/app.css',
	'html/js/mustache.min.js',
	'html/js/app.js'
}

dependencies {
	'es_extended'
}

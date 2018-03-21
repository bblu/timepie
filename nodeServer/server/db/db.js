const mongoose = require('mongoose')
const config = require('config-lite')

// mongodb 连接🔗
mongoose.connect(config.mongodb)
// 此处防止 node.js - Mongoose: mpromise 错误
mongoose.Promise = global.Promise;
var db = mongoose.connection;
db.on('error', console.error.bind(console, 'Connect error'))
db.once('open', function () {
	console.log('Mongodb started successfully')
})

var userSchema = mongoose.Schema({
	email: String,
	password: String,
	recheck: String,
	token: String,
	create_time: Date
})

var doneSchema = mongoose.Schema({
	id: {type:Number,index:true},
	code: {type:Number,index:true},
	star: Number,
	stop: Number,
	span: Number,
	spnd: Number,
	name: String,
	alia: String,
	desc: String,
	user: String
})

var model = {
	// 在此处扩展 model，例如：
	// Article: mongoose.model('Article', articleSchema),
	User: mongoose.model('User', userSchema),
	Done: mongoose.model('Done',doneSchema)
}

module.exports = model

const express = require('express')
const model = require('../db/db.js')
const router = express.Router()
const moment = require('moment')
const objectIdToTimestamp = require('objectid-to-timestamp')
const createToken = require('../middleware/createToken.js')
const sha1 = require('sha1')
const checkToken = require('../middleware/checkToken.js')

// 获取数据
const done = (req, res) => {
	model.Done.find({}, (err, doc) => {
		if(err) console.log(err)
		res.send(doc)
	})
}
// 备份数据
const bkup = (req, res) => {
	let items = req.body
	console.log(req.body)
	model.Done.insertMany(items,(err, doc) => {
		if(err) console.log(err)
		if(!doc) {
			console.log("没有有效数据");
			res.json({
				info: false
			})
		} else {
			console.log('备份成功')
			var name = req.body.email;
			res.json({
				success: true
			})
		}
	})
}



module.exports = (router) => {
	router.get('/done', done),
	router.post('/done', bkup)
}

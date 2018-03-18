const express = require('express')
const controller = require('../controller/done.js')
const router = express.Router()

controller(router)

module.exports = router

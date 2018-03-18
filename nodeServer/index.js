const express = require('express')
const path = require('path')
const bodyParser = require('body-parser')
const cookieParser = require('cookie-parser')
const favicon = require('serve-favicon')
const logger = require('morgan')
const userRoutes = require('./server/routes/user.js')
const doneRoutes = require('./server/routes/done.js')
const config = require('config-lite')
const compression = require('compression')
const app = express()


app.use(logger('dev'));
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: false }));
app.use(cookieParser());

app.use(compression({ threshold: 0 }));
app.use('/',)
app.use('/user', userRoutes);
app.use('/done', doneRoutes);

app.use(function (req, res, next) {
	var err = new Error('This page not found');
	err.status = 404;
	next(err)
})

app.listen(8008, function () {
	console.log(`Server running in port ${config.port}`)
})

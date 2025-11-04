const express = require('express');
const cors = require('cors');
const axios = require('axios');
require('dotenv').config();

const app = express();
const port = process.env.PORT || 5000;

app.use(cors());
app.use(express.json());

app.get('/api/weather/:city', async (req, res) => {
    try {
        const { city } = req.params;
        const response = await axios.get(
            `https://api.openweathermap.org/data/2.5/weather?q=${city}&appid=${process.env.WEATHER_API_KEY}&units=metric`
        );
        res.json(response.data);
    } catch (error) {
        // log detailed error for debugging
        console.error('Weather API error:', error && error.toString());
        if (error && error.response) {
            console.error('Weather API response status:', error.response.status);
            console.error('Weather API response data:', error.response.data);
        }
        res.status(500).json({ message: 'Error fetching weather data' });
    }
});

app.listen(port, () => {
    console.log(`Server is running on port ${port}`);
});
import React, { useState } from 'react';
import axios from 'axios';
import './App.css';

function App() {
  const [city, setCity] = useState('');
  const [weather, setWeather] = useState(null);
  const [error, setError] = useState('');

  const getWeather = async (e) => {
    e.preventDefault();
    try {
      const response = await axios.get(`http://localhost:5001/api/weather/${city}`);
      setWeather(response.data);
      setError('');
    } catch (err) {
      setError('Error fetching weather data');
      setWeather(null);
    }
  };

  return (
    <div className="App">
      <header className="App-header">
        <h1>WeatherNow</h1>
        <form onSubmit={getWeather}>
          <input
            type="text"
            value={city}
            onChange={(e) => setCity(e.target.value)}
            placeholder="Enter city name"
          />
          <button type="submit">Get Weather</button>
        </form>

        {error && <p className="error">{error}</p>}

        {weather && (
          <div className="weather-info">
            <h2>{weather.name}</h2>
            <p>Temperature: {weather.main.temp}°C</p>
            <p>Weather: {weather.weather[0].main}</p>
            <p>Humidity: {weather.main.humidity}%</p>
          </div>
        )}
      </header>
    </div>
  );
}

export default App;
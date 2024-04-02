import React from 'react';
import ReactDOM from 'react-dom/client';
import App from './App'; // Assuming 'app.js' is now a TypeScript output
import { BrowserRouter } from 'react-router-dom';
import { PersistGate } from 'redux-persist/integration/react';
import { Provider } from 'react-redux';
import {
  persistor,
  store,
} from './redux/store'; // Ensure proper types are defined for store and persistor
import './styles/index.css';

const root = ReactDOM.createRoot(document.getElementById('root') as HTMLElement);
root.render(
  <React.StrictMode>
    <Provider store={store}>
      <PersistGate loading={null} persistor={persistor}>
        <BrowserRouter basename="/electro-world">
          <App />
        </BrowserRouter>
      </PersistGate>
    </Provider>
  </React.StrictMode>
);
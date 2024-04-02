import axios from "axios";
import { createAsyncThunk } from "@reduxjs/toolkit";

axios.defaults.baseURL = 'https://655b1ab5ab37729791a88e4c.mockapi.io/api/v1/';

export const fetchProducts = createAsyncThunk<Product[]>(
  'products/fetchAll',
  async (_, thunkAPI) => {
    try {
      const response = await axios.get('/product');
      return response.data;
    } catch (e) {
      return thunkAPI.rejectWithValue(e.message);
    }
  }
);
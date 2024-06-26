import axios from "axios";
import { createAsyncThunk } from "@reduxjs/toolkit";
import {Product} from "../redux/slice/productSlice";

axios.defaults.baseURL = 'https://655b1ab5ab37729791a88e4c.mockapi.io/api/v1/';

// export const fetchProducts = createAsyncThunk<Product[]>(
export const fetchProducts = createAsyncThunk<Product[]>(
  'products/fetchAll',
  async (_, thunkAPI) => {
    try {
      const response = await axios.get('/product');
      return response.data;
    } catch (e: any) {
      return thunkAPI.rejectWithValue(e.message);
    }
  }
);
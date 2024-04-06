import { createSlice } from "@reduxjs/toolkit";
// import { PersistPartial } from 'redux-persist';
import { PersistPartial } from 'redux-persist';


interface OrderItem {
  id: number; 
}

export interface OrdersState {
  items: OrderItem[];
}

export const initialState: OrdersState = {
  items: [],
};

const ordersSlice = createSlice<OrdersState & PersistPartial, any>({
  name: 'orders',
  initialState,
  reducers: {
    addOrders(state: any, action: { payload: OrderItem[] }) {
      state.items.push(...action.payload); 
    },
    deleteOrders(state: any, action: { payload: number }) {
      const index = state.items.findIndex(item => item.id === action.payload);
      state.items.splice(index, 1);
    },
    updateOrders(state: any, action: { payload: OrderItem }) {
      const index = state.items.findIndex(item => item.id === action.payload.id);
      if (index !== -1) {
        state.items.splice(index, 1, action.payload);
      }
    },
    deleteAllOrders(state: any) {
      state.items = [];
    },
  },
});

export const { addOrders, deleteOrders, updateOrders, deleteAllOrders } = ordersSlice.actions;
export const ordersReducer = ordersSlice.reducer;
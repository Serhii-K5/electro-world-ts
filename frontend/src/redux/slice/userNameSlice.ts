import { createSlice } from "@reduxjs/toolkit";

export interface UserNameState {
  name: string;
}

const initialState: UserNameState = {
  name: "",
};

const userNameSlice = createSlice<UserNameState & PersistPartial, any>({
  name: "userName",
  initialState,
  reducers: {
    changeUserName(state, action: { payload: string }) {
      state.name = action.payload;
    },
  },
});

export const { changeUserName } = userNameSlice.actions;
export const userNameReducer = userNameSlice.reducer;
import { createSlice } from "@reduxjs/toolkit";
import { PersistPartial } from 'redux-persist';

// подключить для определения языка по языку системы
// const userLanguage = navigator.language;

export interface LanguageState {
  language: number;
}

export const initialState: LanguageState = {
  // language: 'UA',
  // отключить при определении языка по языку системы
  language: 0,
  // подключить при определении языка по языку системы
  // language: userLanguage === 'ru' ? 1 : 0,
};

const sliceLanguage = createSlice<LanguageState & PersistPartial, any>({
  name: "languages",
  initialState,
  reducers: {
    changeLanguage(state: any, action: { payload: number }) {
      state.language = action.payload;
    },
  },
});

export const { changeLanguage } = sliceLanguage.actions;
export const languagesReducer = sliceLanguage.reducer;

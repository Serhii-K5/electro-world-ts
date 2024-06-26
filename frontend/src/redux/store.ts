import {
  persistStore,
  persistReducer,
  // PersistPartial,
  FLUSH,
  REHYDRATE,
  PAUSE,
  PERSIST,
  PURGE,
  REGISTER,
} from 'redux-persist';
import storage from 'redux-persist/lib/storage';
import { configureStore } from '@reduxjs/toolkit';
import { productsReducer } from './slice/productSlice';
import { ordersReducer } from './slice/orderSlice';
import { languagesReducer } from './slice/languageSlice';
import { directoryPathReducer } from './slice/directoryPathSlice';
import { categoriesReducer } from './slice/categorySlice';
import { filtersReducer } from './slice/filtersSlice';
import { userNameReducer } from './slice/userNameSlice';

import { ProductsState } from './slice/productSlice';
import { OrdersState } from './slice/orderSlice';
import { LanguageState } from './slice/languageSlice';
import { DirectoryPathState } from './slice/directoryPathSlice';
import { CategoryState } from './slice/categorySlice';
import { FiltersState } from './slice/filtersSlice';
import { UserNameState } from './slice/userNameSlice';

export interface RootState {
  products: ProductsState;
  // orders: OrdersState;
  orders: { items: OrderItem[] };
  languages: LanguageState;
  directoryPath: DirectoryPathState;
  categories: CategoryState;
  filters: FiltersState;
  userName: UserNameState;
}


const ordersPersistConfig = {
  key: 'orders',
  storage,
};

const languagesPersistConfig = {
  key: 'languages',
  storage,
};

const directoryPathPersistConfig = {
  key: 'directoryPath',
  storage,
};

const categoriesPersistConfig = {
  key: 'categories',
  storage,
};

const filtersPersistConfig = {
  key: 'filters',
  storage,
};

const userNamePersistConfig = {
  key: 'userName',
  storage,
};

export const store = configureStore({
  reducer: {
    products: productsReducer,
    orders: persistReducer(ordersPersistConfig, ordersReducer),
    languages: persistReducer(languagesPersistConfig, languagesReducer),
    directoryPath: persistReducer(directoryPathPersistConfig, directoryPathReducer),
    categories: persistReducer(categoriesPersistConfig, categoriesReducer),
    filters: persistReducer(filtersPersistConfig, filtersReducer),
    userName: persistReducer(userNamePersistConfig, userNameReducer),
  },
  middleware: getDefaultMiddleware =>
    getDefaultMiddleware({
      serializableCheck: {
        ignoredActions: [FLUSH, REHYDRATE, PAUSE, PERSIST, PURGE, REGISTER],
      },
    }),
});

export const persistor = persistStore(store);


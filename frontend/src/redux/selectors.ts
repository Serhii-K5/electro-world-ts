import { RootState } from "./store"  // Import RootState type

export const selectProducts = (state: RootState) => state.products.items;
export const selectIsProductsLoading = (state: RootState) => state.products.isLoading;
export const selectProductsError = (state: RootState) => state.products.error;

export const selectOrders = (state: RootState) => state.orders.items;

export const selectLanguages = (state: RootState) => state.languages.language;

export const selectDirectoryPath = (state: RootState) => state.directoryPath.items;

export const selectCategories = (state: RootState) => state.categories.category;

export const selectFilters = (state: RootState) => state.filters.items;

export const selectUserName = (state: RootState) => state.userName.name;
// export const selectProducts = (state) => state.products.items;
export const selectProducts = (state) => state.products;
export const selectIsProductsLoading = (state) => state.products.isLoading;
export const selectProductsError = (state) => state.products.error;

export const selectOrders = (state) => state.orders.items;

export const selectLanguages = state => state.languages.language;

export const selectDirectoryPath = state => state.directoryPath.items;

export const selectCategories = state => state.categories.category;

export const selectFilters = state => state.filters.items;

export const selectUserName = state => state.userName.name;



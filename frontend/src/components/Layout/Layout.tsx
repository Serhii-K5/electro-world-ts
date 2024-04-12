// import { useState } from 'react';
// import { Outlet, Link } from 'react-router-dom';
// import { DivUpper, DivBtn, Div, Header } from './Layout.styled';
// import Logo from '../../components/Logo/Logo';

// import ShoppingCart from '../ShoppingCart/ShoppingCart';

// import { useSelector } from 'react-redux';
// import { selectOrders, selectLanguages } from '../../redux/selectors';

// import MessageModule from '../../components/Feedback/Feedback';
// import { LanguageBar } from '../../components/LanguageBar/LanguageBar';
// import AdressBar from '../../components/AdressBar/AdressBar';
// import Authorization from '../../components/Authorization/Authorization';
// import Footer from '../../components/Footer/Footer';

// import NavLinkBar from '../../components/NavLinkBar/NavLinkBar';
// import SearchField from '../../components/SearchField/SearchField';
// import lang from '../../assets/json/language.json';

// export default function Layout() {
//   const orderProducts = useSelector(selectOrders);
//   const [isModalShown, setIsModalShown] = useState(false);
//   const languages = useSelector(selectLanguages);

//   const onCloseModal = () => {
//     setIsModalShown(false);
//   };

//   return (
//     <>
//       <DivUpper>
//         <DivBtn>{lang[languages].layout_minOrder}</DivBtn>
//         <LanguageBar />
//         <Authorization />
//       </DivUpper>
//       <Div>
//         <Header>
//           <Link to="/">
//             <Logo />
//           </Link>
//           <SearchField />
//           <AdressBar color="blue" />
//           <Link to="/orders">
//             <ShoppingCart quantity={orderProducts.length} />
//           </Link>
//         </Header>
//       </Div>
//       <NavLinkBar />
//       {isModalShown && <MessageModule onClose={onCloseModal} />}
//       <Outlet />
//       <Footer />
//     </>
//   );
// }



import React, { useState } from 'react';
import { Outlet, Link } from 'react-router-dom';
import { DivUpper, DivBtn, Div, Header } from './Layout.styled';
import Logo from '../../components/Logo/Logo'; // Assuming Logo is a component

import ShoppingCart from '../ShoppingCart/ShoppingCart';

import { useSelector } from 'react-redux';
import { RootState } from '../../redux/store'; // Import your root state type
import { selectOrders, selectLanguages } from '../../redux/selectors'; // Assuming selectors return correct types

import MessageModule from '../../components/Feedback/Feedback';
import { LanguageBar } from '../../components/LanguageBar/LanguageBar';
import AdressBar from '../../components/AdressBar/AdressBar'; // Assuming AdressBar has props
import Authorization from '../../components/Authorization/Authorization';
import Footer from '../../components/Footer/Footer';

import NavLinkBar from '../../components/NavLinkBar/NavLinkBar';
import SearchField from '../../components/SearchField/SearchField';
import lang from '../../assets/json/language.json';
import { OrderItem } from "../../redux/slice/orderSlice";

// import { Product } from "../../constantValues/constants";

interface Language {
  layout_minOrder: string;
}

interface OrderProduct {
  // ... properties of an order product
}

interface AppState extends RootState {
  orders: {
    products: OrderProduct[];
  };
  languages: {
    selectedLanguage: string;
  };
}

export default function Layout(): React.FC {
  // const orderProducts = useSelector<AppState, OrderProduct[]>(selectOrders);

  const orderProducts = useSelector<AppState, OrderItem[]>(selectOrders);

  const [isModalShown, setIsModalShown] = useState(false);
  const languages = useSelector<AppState, Language>(selectLanguages);

  const onCloseModal = () => {
    setIsModalShown(false);
  };

  return (
    <>
      <DivUpper>
        <DivBtn>{lang[languages.selectedLanguage].layout_minOrder}</DivBtn>
        <LanguageBar />
        <Authorization />
      </DivUpper>
      <Div>
        <Header>
          <Link to="/">
            <Logo />
          </Link>
          <SearchField />
          <AdressBar color="blue" /> {/* Assuming AdressBar accepts color prop */}
          <Link to="/orders">
            <ShoppingCart quantity={orderProducts.length} />
          </Link>
        </Header>
      </Div>
      <NavLinkBar />
      {isModalShown && <MessageModule onClose={onCloseModal} />}
      <Outlet />
      <Footer />
    </>
  );
}

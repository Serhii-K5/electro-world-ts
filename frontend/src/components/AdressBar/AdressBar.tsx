import React, { useState } from 'react';
import { BsFillTelephoneFill } from 'react-icons/bs';
import { SiVodafone } from 'react-icons/si';
import { FaViber } from 'react-icons/fa';
import ks from '../../assets/images/svg/kyivstar.svg';
import { VodafoneBg, Span } from './AdressBar.styled';
import { PHONE_KS, PHONE_KS_STR, PHONE_MTC, PHONE_MTC_STR } from '../../constantValues/constants';

interface AdressBarProps {
  color: string;
}

const AdressBar: React.FC<AdressBarProps> = ({ color }) => {
  const [isFocus, setIsFocus] = useState<number>(0);
  const telKS: string = "tel:" + PHONE_KS;
  const telMTC: string = "tel:" + PHONE_MTC;

  return (
    <div>
      <div
        style={{ display: 'flex' }}
        onMouseMove={() => setIsFocus(1)}
        onMouseOut={() => setIsFocus(0)}
      >
        <a href={telKS}>
          <div style={{ display: 'flex' }}>
            <BsFillTelephoneFill style={{ position: 'relative', top: '3px', right: '-17px', color: 'var(--primary-white)' }} />
            <BsFillTelephoneFill style={{ position: 'relative', top: '3px' }} />
            <img src={ks} alt="kyivstar logo" />
            <Span id={color} className={isFocus === 1 ? 'isScaleKs' : ''}> {PHONE_KS_STR} </Span>
          </div>
        </a>
        <FaViber style={{ marginLeft: '3px', fill: 'blueviolet' }} />
      </div>
      <div
        style={{ display: 'flex' }}
        onMouseMove={() => setIsFocus(2)}
        onMouseOut={() => setIsFocus(0)}
      >
        <a href={telMTC} style={{ display: 'block' }}>
          <BsFillTelephoneFill style={{ position: 'relative', top: '3px', right: '-18px', color: 'var(--primary-white)' }} />
          <BsFillTelephoneFill style={{ position: 'relative', top: '3px' }} />
          <VodafoneBg>
            <SiVodafone style={{ fill: 'red' }} />
          </VodafoneBg>
          <Span id={color} className={isFocus === 2 ? 'isScaleVd' : ''}> {PHONE_MTC_STR} </Span>
        </a>
      </div>
    </div>
  );
};

export default AdressBar;

'use client';

import CanvasDraw from "react-canvas-draw";

const Canvas = (_props: {}) => <CanvasDraw 
            lazyRadius={0} 
            brushRadius={7}
            style={{ position: 'relative' }}
            backgroundColor='white'
            hideGrid={true}
            immediateLoading={true}
            loadTimeOffset={0}
          />;

export default Canvas;


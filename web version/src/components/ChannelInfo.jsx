import React from "react";
import "../styles/ChannelInfo.css";
import logo from "../assets/smallIcon2.png"; // keep this path as you have it

const ChannelInfo = () => {
  return (
    <div className="channelInfo-box">
      <h3 className="channelInfo-title">
        <span className="prayer-logoWrap">
                  <img style={{ width: "70px", height: "70px" }} src={logo} alt="makkah logo" />
                </span>
                 ترددات قناة مكة</h3>

      <div className="channelInfo-grid">
        <div className="channelInfo-item">
          <span className="channelInfo-label">القمر</span>
          <span className="channelInfo-value">عربسات بدر</span>
        </div>
    
        <div className="channelInfo-item">
          <span className="channelInfo-label">التردد</span>
          <span className="channelInfo-value">11398</span>
        </div>

        <div className="channelInfo-item">
          <span className="channelInfo-label">الاستقطاب</span>
          <span className="channelInfo-value">عمودي</span>
        </div>

        <div className="channelInfo-item">
          <span className="channelInfo-label">الترميز</span>
          <span className="channelInfo-value">27500</span>
        </div>

      </div>
    </div>
  );
};

export default ChannelInfo;

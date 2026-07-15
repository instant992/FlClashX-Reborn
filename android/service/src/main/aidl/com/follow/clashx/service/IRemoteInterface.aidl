// IRemoteInterface.aidl
package com.follow.clashx.service;

import com.follow.clashx.service.ICallbackInterface;
import com.follow.clashx.service.IEventInterface;
import com.follow.clashx.service.IResultInterface;
import com.follow.clashx.service.IVoidInterface;
import com.follow.clashx.service.models.VpnOptions;
import com.follow.clashx.service.models.NotificationParams;

interface IRemoteInterface {
    void invokeAction(in String data, in ICallbackInterface callback);
    void quickSetup(in String initParamsString, in String setupParamsString, in ICallbackInterface callback, in IVoidInterface onStarted);
    void updateNotificationParams(in NotificationParams params);
    void startService(in VpnOptions options, in long runTime, in IResultInterface result);
    void stopService(in IResultInterface result);
    void setEventListener(in IEventInterface event);
    void setCrashlytics(in boolean enable);
    long getRunTime();
}
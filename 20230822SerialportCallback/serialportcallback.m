s = serialport("/dev/cu.usbmodem21401", 115200);
configureTerminator(s, "CR/LF");
configureCallback(s,"byte",3,@callbackFcn);
s.BytesAvailableFcnMode;
s.BytesAvailableFcn;

function callbackFcn(~,~)
disp('mouse licked')
end

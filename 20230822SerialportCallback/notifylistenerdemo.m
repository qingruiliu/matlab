global h 
h.CurrState = BehState_MaPlas;
h.s = serialport("/dev/cu.usbmodem21401", 115200);
configureTerminator(h.s, "CR/LF");
configureCallback(h.s,"byte",3,@serialportRead);

h.lickListener = addlistener(h.CurrState, 'MouseLicked', @reportlick);

h.tLickListener = timer('TimerFcn',@lickreporter,'BusyMode','error','TasksToExecute',1);


function reportlick(~,~)
global h 
    disp('timer start');
    start(h.tLickListener)
end

function lickreporter(~,~)
    disp('mouse licked 111')
end

function serialportRead(~,~)
    global h 
    h.CurrState.triggerMouseLicked()
end

